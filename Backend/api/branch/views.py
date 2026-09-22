from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import Branch
from .serializers import BranchSerializer


@api_view(['GET', 'POST'])
def branch_list_create(request):
    """
    GET: List all branches.
    POST: Create a branch (CEO only).
    """
    if request.method == 'GET':
        branches = Branch.objects.all().order_by('-created_at')
        serializer = BranchSerializer(branches, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        if getattr(request.user, 'role', '') != 'ceo':
            return Response({"error": "Only CEO can create branches."}, status=status.HTTP_403_FORBIDDEN)

        name = request.data.get('name', '').strip()
        if not name:
            return Response({"error": "Branch name is required."}, status=status.HTTP_400_BAD_REQUEST)
        if Branch.objects.filter(name__iexact=name).exists():
            return Response({"error": f"A branch with the name '{name}' already exists."}, status=status.HTTP_400_BAD_REQUEST)

        serializer = BranchSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(created_by=request.user.firebase_uid)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PATCH', 'DELETE'])
def branch_detail(request, pk):
    """Retrieve, update, or delete a branch."""
    try:
        branch = Branch.objects.get(pk=pk)
    except Branch.DoesNotExist:
        return Response({"error": "Branch not found"}, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = BranchSerializer(branch)
        return Response(serializer.data)

    if getattr(request.user, 'role', '') != 'ceo':
        return Response({"error": "Only CEO can modify or delete branches."}, status=status.HTTP_403_FORBIDDEN)

    if request.method == 'PATCH':
        serializer = BranchSerializer(branch, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        branch.delete()
        return Response({"message": "Branch deleted successfully"}, status=status.HTTP_200_OK)
